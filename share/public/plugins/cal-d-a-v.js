(function () {
	'use strict';

	angular.module('StatusDashboard').directive('caldav', [
		'statusService',
		'moment',
		function (statusService, moment) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.events = [];
					scope.clusteredEvents = [];
					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						scope.events = newValue;
						scope.clusteredEvents = {};
						scope.events.forEach(function (event) {
							var dateString = moment(event.start).format('YYYY-MM-DD');
							if (!scope.clusteredEvents[dateString]) {
								scope.clusteredEvents[dateString] = [];
							}
							scope.clusteredEvents[dateString].push(event);
						});
					});
					scope.$watch('dayClusterStr', function (newValue, oldValue) {
						scope.dayCluster = scope.$eval(newValue);
					});
					scope.$watch('timesStr', function (newValue, oldValue) {
						scope.times = (newValue === null || newValue === undefined)
							? true
							: scope.$eval(newValue);
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/caldav.html',
				scope:       {
					statusId:      '@statusId',
					statusTitle:   '@statusTitle',
					dateFormat:    '@dateFormat',
					dayClusterStr: '@dayCluster',
					timesStr:      '@times',
					count:         '@count'
				}
			}
		}
	]);
}());
