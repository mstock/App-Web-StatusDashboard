(function () {
	'use strict';

	angular.module('StatusDashboard').directive('jenkins', [
		'statusService',
		function (statusService) {
			return {
				restrict:    'E',
				link:        function (scope, element, attrs) {
					scope.$watch(function () {
						return statusService.getStatus(scope.statusId)
					}, function (newValue, oldValue) {
						if (newValue === null) {
							return;
						}
						console.log("Old: ", oldValue, "New: ", newValue);

						scope.totalExecutors = newValue.totalExecutors;
						scope.busyExecutors  = newValue.busyExecutors;
						scope.idleExecutors  = newValue.totalExecutors - newValue.busyExecutors;
						scope.busyPercent    = 100 * newValue.busyExecutors / newValue.totalExecutors;
						scope.idlePercent    = 100 - scope.busyPercent;
					});
				},
				replace:     false,
				templateUrl: 'plugins/templates/jenkins.html',
				scope:       {
					statusId: '@statusId',
					title:    '@title'
				}
			}
		}
	]);
}());
