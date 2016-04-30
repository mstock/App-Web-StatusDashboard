(function () {
	'use strict';

	angular.module('StatusDashboard', [
		'ngMessages',
		'ngWebSocket',
		'ngMessageFormat',
		'chart.js',
		'angularMoment'
	]).service('statusService', [
		'$http',
		'$websocket',
		'websocketUri',
		function ($http, $websocket, websocketUri) {
			var status = {};

			var dataStream = $websocket(websocketUri);
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
				}
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
							scope.lastUpdated = moment(newValue, 'YYYYMMDDTHHmmssZ');
						}
					);
				},
				replace:     false,
				templateUrl: 'app/templates/status-display.html',
				scope:       {
					titlePrefix: '@titlePrefix',
					titleSuffix: '@titleSuffix',
					statusId:    '@statusId'
				},
				transclude:  true
			}
		}
	]);
})();
