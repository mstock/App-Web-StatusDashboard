(function () {
	'use strict';

	angular.module('StatusDashboard', [
		'ngMessages',
		'ngWebSocket',
		'ngMessageFormat',
		'chart.js',
		'angularMoment',
		'ui.bootstrap'
	]).service('statusService', [
		'$http',
		'$websocket',
		'websocketUri',
		'$log',
		function ($http, $websocket, websocketUri, $log) {
			var status = {};
			var isConnected;

			var dataStream = $websocket(websocketUri);
			dataStream.onOpen(function () {
				isConnected = true;
			});
			dataStream.onError(function (error) {
				isConnected = false;
				$log.error("WebSocket error: ", error);
			});
			dataStream.onClose(function (message) {
				isConnected = false;
				$log.debug("Connection closed: ", message);
				dataStream.reconnect();
			});
			dataStream.onMessage(function(message) {
				var data = JSON.parse(message.data);
				Object.keys(data).forEach(function (key) {
					status[key] = data[key];
				});
			});

			return {
				getStatus: function (serviceId) {
					return (status && serviceId && serviceId in status)
						? status[serviceId].data
						: null;
				},
				getLastUpdated: function (serviceId) {
					return (status && serviceId && serviceId in status)
						? status[serviceId].last_updated
						: null;
				},
				isConnected: function () {
					return isConnected;
				}
			};
		}
	]).directive('theme', [
		'$location',
		function ($location) {
			return {
				restrict: 'A',
				link:     function (scope, element, attrs) {
					scope.$watch('theme', function (newValue, oldValue) {
						if (oldValue) {
							element.removeClass(oldValue);
						}
						if (newValue) {
							element.addClass(newValue);
						}
					});
					scope.$watch(function () {
						return $location.search().theme;
					}, function (newValue) {
						scope.theme = (angular.isString(newValue) && newValue !== '')
							? newValue
							: attrs.theme;
					});
				},
				scope:    {
					theme: '@theme'
				}
			};
		}
	]).directive('socketConnectionState', [
		'statusService',
		function (statusService) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.isConnected();
					}, function (newValue) {
						scope.isConnected = newValue;
					});
				},
				replace:     false,
				templateUrl: 'app/templates/socket-connection-state.html'
			};
		}
	]).directive('statusDisplay', [
		'statusService',
		'moment',
		function (statusService, moment) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.$watch(
						function() {
							return statusService.getLastUpdated(scope.statusId)
						},
						function(newValue, oldValue) {
							if (newValue === null) {
								return;
							}
							scope.lastUpdated = moment(newValue);
						}
					);
					scope.$watch('showLastUpdatedStr', function (newValue) {
						scope.showLastUpdated = newValue !== undefined
							? scope.$eval(newValue)
							: true;
					});
				},
				replace:     false,
				templateUrl: 'app/templates/status-display.html',
				scope:       {
					statusTitle:        '@statusTitle',
					statusId:           '@statusId',
					showLastUpdatedStr: '@showLastUpdated'
				},
				transclude:  true
			}
		}
	]).directive('clock', [
		'$interval',
		function ($interval) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					$interval(function () {
						scope.now = new Date();
					}, 1000);
				},
				replace:     false,
				templateUrl: 'app/templates/clock.html',
				scope:       {
					statusTitle: '@statusTitle',
					dateFormat:  '@dateFormat'
				}
			}
		}
	]).directive('countdown', [
		function () {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {},
				replace:     false,
				templateUrl: 'app/templates/countdown.html',
				scope:       {
					statusTitle:        '@statusTitle',
					dateFormat:         '@dateFormat',
					countdownPrefix:    '@countdownPrefix',
					countdownTimestamp: '@countdownTimestamp',
				}
			}
		}
	]);
})();
